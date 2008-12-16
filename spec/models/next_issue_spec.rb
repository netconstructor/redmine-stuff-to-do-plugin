require File.dirname(__FILE__) + '/../spec_helper'

describe NextIssue, 'associations' do
  it 'should belong to an Issue' do
    NextIssue.should have_association(:issue, :belongs_to)
  end

  it 'should belong to a user' do
    NextIssue.should have_association(:user, :belongs_to)
  end
end

describe NextIssue, '#available' do
  it 'should find all assigned issues for the user' do
    user = mock_model(User)
    issues = []
    10.times do |issue_number|
      issues << mock_model(Issue, :id => issue_number, :assigned_to => user)
    end

    Issue.should_receive(:find).with(:all, { :conditions => ['assigned_to_id = ? AND issue_statuses.is_closed = ?',user.id, false ], :include => :status} ).and_return(issues)
    NextIssue.available(user).should eql(issues)
  end

  it 'should not include issues that are NextIssues' do
    user = mock_model(User)
    issues = []
    next_issues = []
    10.times do |issue_number|
      issue = mock_model(Issue, :id => issue_number, :assigned_to => user)
      issues << issue
      # Add in half the issues as NextIssues
      next_issues << mock_model(NextIssue, :issue => issue) if issue_number.even?
    end
    
    Issue.should_receive(:find).with(:all, { :conditions => ['assigned_to_id = ? AND issue_statuses.is_closed = ?',user.id, false ], :include => :status} ).and_return(issues)
    NextIssue.should_receive(:find).with(:all, { :conditions => { :user_id => user.id }}).and_return(next_issues)
    NextIssue.available(user).should eql(issues - next_issues.collect(&:issue))
  end
  
  it 'should only include open issues' do
    user = mock_model(User)
    issues = []
    10.times do |issue_number|
      issues << mock_model(Issue, :id => issue_number, :assigned_to => user)
    end

    Issue.should_receive(:find).with(:all, { :conditions => ['assigned_to_id = ? AND issue_statuses.is_closed = ?',user.id, false ], :include => :status } ).and_return(issues)
    available = NextIssue.available(user)
    available.should have(10).items
    available.should eql(issues)
  end
end


describe NextIssue, '#closing_issue' do
  before(:each) do
    @issue = mock_model(Issue)
    @issue.stub!(:closed?).and_return(true)
  end
  
  it 'should do nothing if the issue is still open' do
    @issue.should_receive(:closed?).and_return(false)
    NextIssue.closing_issue(@issue)
  end

  it 'should delete all NextIssues for the closed issue' do
    next_issue_one = mock_model(NextIssue, :issue_id => @issue.id)
    next_issue_one.should_receive(:destroy).and_return(true)
    next_issue_two = mock_model(NextIssue, :issue_id => @issue.id)
    next_issue_two.should_receive(:destroy).and_return(true)
    next_issues = [next_issue_one, next_issue_two]
    NextIssue.should_receive(:find).with(:all, { :conditions => { :issue_id => @issue.id }}).and_return(next_issues)

    NextIssue.closing_issue(@issue)
  end
end
