require  'test_helper'

class TaskTest < Test::Unit::TestCase
  def setup
    @things = @@things ||= Things.new(:database => DATABASE_FIXTURE_PATH)
  end
  
  def find_task(name)
    title = {
      :with_tags   => 'today item with multiple tags',
      :basic       => 'today item',
      :with_parent => 'email bar'
    }[name]
    @things.today.detect { |t| t.title == title }
  end
  
  def task_with_children
    task_by_id("z154")
  end
  
  def task_by_id(id)
    node = @things.database.at("object[@type='TODO']##{id}")
    Things::Task.new(node, @things.database)
  end

  test "should use the task's title for to_s" do
    task = find_task(:basic)
    assert_equal("today item", task.to_s)
  end

  test "should find the task's tag ids" do
    task = find_task(:with_tags)
    assert_instance_of Array, task.tag_ids
    assert_equal %w[z151 z150].sort, task.tag_ids.sort
  end
  
  test "should not find any tags if there isnt any" do
    assert_equal 0, find_task(:basic).tag_ids.length
  end
  
  test "should find the task's tag titles" do
    task = find_task(:with_tags)
    assert_equal(%w[Home City].sort, task.tags.sort)
  end
  
  test "should know if there are any tags" do
    assert(find_task(:with_tags).tags?)
    assert(!find_task(:basic).tags?)
  end
  
  test "if the task has a specific tag" do
    task = find_task(:with_tags)
    assert(task.tag?("Home"))
    assert(!task.tag?("Errand"))
  end
  
  test "should find the tasks parent_id" do
    task = find_task(:with_parent)
    assert_equal("z154", task.parent_id)
  end
  
  test "should not find the task's parent project if it doesn't have any" do
    task = find_task(:basic)
    assert_equal(nil, task.parent_id)
  end
  
  test "should find the parent's title" do
    task = find_task(:with_parent)
    assert_equal "Make dinner", task.parent.title
  end
  
  test "should know if there is a parent project" do
    assert(find_task(:with_parent).parent?)
    assert(!find_task(:basic).parent?)
  end
  
  test "should know if the task is completed" do
    @things.today.each do |task|
      if task.title.include?('complete')
        assert(task.complete?)
        assert(!task.incompleted?)
      else
        assert(task.incompleted?)
        assert(!task.completed?)
      end
    end
  end

  test "if a task is canceled" do
    assert task_by_id("z189").canceled?
  end

  test "should find the task's order index" do
    assert_equal(7, find_task(:basic).position.to_i)
  end
  
  test "list the tasks children" do
    assert_instance_of(Array, task_with_children.children)
  end
  
  test "find the right number of children" do
    assert_equal(9, task_with_children.children.length)
  end
  
  test "know if there are child tasks" do
    assert task_with_children.children?
    assert !find_task(:basic).children?
  end
  
  test "populate the children array with Task objects" do
    assert task_with_children.children.all? { |c| c.class == Things::Task }
  end
  
  test "find the children_ids" do
    ids = %w[z163 z161 z160 z157 z159 z156 z165 z158 z162].sort
    assert_equal(ids, task_with_children.children_ids.sort)
  end
end